/*
 * Copyright (c) 2010-2025 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "uianchorlayout.h"
#include "uigridlayout.h"
#include "uihorizontallayout.h"
#include "uitranslator.h"
#include "uiverticallayout.h"
#include "uiwidget.h"

#include <framework/graphics/drawpoolmanager.h>
#include <framework/graphics/texture.h>
#include <framework/graphics/texturemanager.h>

#include <framework/core/eventdispatcher.h>

#include <atomic>

void UIWidget::initBaseStyle()
{
    static std::atomic<uint32_t > UID(0);
    m_borderColor.set(Color::black);

    // generate an unique id, this is need because anchored layouts find widgets by id
    m_id = fmt::format("widget{}", ++UID);
}

void UIWidget::parseBaseStyle(const OTMLNodePtr& styleNode)
{
    // parse lua variables and callbacks first
    for (const auto& node : styleNode->children()) {
        // lua functions
        if (node->tag().starts_with("@")) {
            // load once
            if (hasProp(PropFirstOnStyle)) {
                std::string funcName = node->tag().substr(1);
                std::string funcOrigin = "@" + node->source() + ": [" + node->tag() + "]";
                g_lua.loadFunction(node->value(), funcOrigin);
                luaSetField(funcName);
            }
            // lua fields value
        } else if (node->tag().starts_with("&")) {
            std::string fieldName = node->tag().substr(1);
            std::string fieldOrigin = "@" + node->source() + ": [" + node->tag() + "]";

            g_lua.evaluateExpression(node->value(), fieldOrigin);
            luaSetField(fieldName);
        }
    }
    // load styles used by all widgets
    for (const auto& node : styleNode->children()) {
        if (node->tag() == "background-draw-order")
            setBackgroundDrawOrder(node->value<int>());
        else if (node->tag() == "border-draw-order")
            setBorderDrawOrder(node->value<int>());
        else if (node->tag() == "icon-draw-order")
            setIconDrawOrder(node->value<int>());
        else if (node->tag() == "image-draw-order")
            setImageDrawOrder(node->value<int>());
        else if (node->tag() == "text-draw-order")
            setTextDrawOrder(node->value<int>());
        else if (node->tag() == "color")
            setColor(node->value<Color>());
        else if (node->tag() == "shader")
            setShader(node->value());
        else if (node->tag() == "x")
            setX(node->value<int>());
        else if (node->tag() == "y")
            setY(node->value<int>());
        else if (node->tag() == "pos")
            setPosition(node->value<Point>());
        else if (node->tag() == "width")
            setWidth(node->value<int>());
        else if (node->tag() == "height")
            setHeight(node->value<int>());
        else if (node->tag() == "min-width")
            setMinWidth(node->value<int>());
        else if (node->tag() == "max-width")
            setMaxWidth(node->value<int>());
        else if (node->tag() == "min-height")
            setMinHeight(node->value<int>());
        else if (node->tag() == "max-height")
            setMaxHeight(node->value<int>());
        else if (node->tag() == "rect")
            setRect(node->value<Rect>());
        else if (node->tag() == "background")
            setBackgroundColor(node->value<Color>());
        else if (node->tag() == "background-color")
            setBackgroundColor(node->value<Color>());
        else if (node->tag() == "background-offset-x")
            setBackgroundOffsetX(node->value<int>());
        else if (node->tag() == "background-offset-y")
            setBackgroundOffsetY(node->value<int>());
        else if (node->tag() == "background-offset")
            setBackgroundOffset(node->value<Point>());
        else if (node->tag() == "background-width")
            setBackgroundWidth(node->value<int>());
        else if (node->tag() == "background-height")
            setBackgroundHeight(node->value<int>());
        else if (node->tag() == "background-size")
            setBackgroundSize(node->value<Size>());
        else if (node->tag() == "background-rect")
            setBackgroundRect(node->value<Rect>());
        else if (node->tag() == "icon")
            setIcon(stdext::resolve_path(node->value(), node->source()));
        else if (node->tag() == "icon-source")
            setIcon(stdext::resolve_path(node->value(), node->source()));
        else if (node->tag() == "icon-color")
            setIconColor(node->value<Color>());
        else if (node->tag() == "icon-offset-x")
            setIconOffsetX(node->value<int>());
        else if (node->tag() == "icon-offset-y")
            setIconOffsetY(node->value<int>());
        else if (node->tag() == "icon-offset")
            setIconOffset(node->value<Point>());
        else if (node->tag() == "icon-width")
            setIconWidth(node->value<int>());
        else if (node->tag() == "icon-height")
            setIconHeight(node->value<int>());
        else if (node->tag() == "icon-size")
            setIconSize(node->value<Size>());
        else if (node->tag() == "icon-rect")
            setIconRect(node->value<Rect>());
        else if (node->tag() == "icon-clip")
            setIconClip(node->value<Rect>());
        else if (node->tag() == "icon-align")
            setIconAlign(Fw::translateAlignment(node->value()));
        else if (node->tag() == "opacity")
            setOpacity(node->value<float>());
        else if (node->tag() == "rotation")
            setRotation(node->value<float>());
        else if (node->tag() == "enabled")
            setEnabled(node->value<bool>());
        else if (node->tag() == "visible")
            setVisible(node->value<bool>());
        else if (node->tag() == "checked")
            setChecked(node->value<bool>());
        else if (node->tag() == "draggable")
            setDraggable(node->value<bool>());
        else if (node->tag() == "on")
            setOn(node->value<bool>());
        else if (node->tag() == "focusable")
            setFocusable(node->value<bool>());
        else if (node->tag() == "auto-focus")
            setAutoFocusPolicy(Fw::translateAutoFocusPolicy(node->value()));
        else if (node->tag() == "phantom")
            setPhantom(node->value<bool>());
        else if (node->tag() == "size")
            setSize(node->value<Size>());
        else if (node->tag() == "fixed-size")
            setFixedSize(node->value<bool>());
        else if (node->tag() == "min-size")
            setMinSize(node->value<Size>());
        else if (node->tag() == "max-size")
            setMaxSize(node->value<Size>());
        else if (node->tag() == "clipping")
            setClipping(node->value<bool>());
        else if (node->tag() == "border") {
            const auto& split = stdext::split(node->value(), " ");
            if (split.size() == 2) {
                setBorderWidth(stdext::safe_cast<int>(split[0]));
                setBorderColor(stdext::safe_cast<Color>(split[1]));
            } else
                throw OTMLException(node, "border param must have its width followed by its color");
        } else if (node->tag() == "border-width")
            setBorderWidth(node->value<int>());
        else if (node->tag() == "border-width-top")
            setBorderWidthTop(node->value<int>());
        else if (node->tag() == "border-width-right")
            setBorderWidthRight(node->value<int>());
        else if (node->tag() == "border-width-bottom")
            setBorderWidthBottom(node->value<int>());
        else if (node->tag() == "border-width-left")
            setBorderWidthLeft(node->value<int>());
        else if (node->tag() == "border-color")
            setBorderColor(node->value<Color>());
        else if (node->tag() == "border-color-top")
            setBorderColorTop(node->value<Color>());
        else if (node->tag() == "border-color-right")
            setBorderColorRight(node->value<Color>());
        else if (node->tag() == "border-color-bottom")
            setBorderColorBottom(node->value<Color>());
        else if (node->tag() == "border-color-left")
            setBorderColorLeft(node->value<Color>());
        else if (node->tag() == "margin-top")
            setMarginTop(node->value<int>());
        else if (node->tag() == "margin-right")
            setMarginRight(node->value<int>());
        else if (node->tag() == "margin-bottom")
            setMarginBottom(node->value<int>());
        else if (node->tag() == "margin-left")
            setMarginLeft(node->value<int>());
        else if (node->tag() == "margin") {
            std::string marginDesc = node->value();
            std::vector<std::string> split = stdext::split(marginDesc, " ");
            if (split.size() == 4) {
                setMarginTop(stdext::safe_cast<int>(split[0]));
                setMarginRight(stdext::safe_cast<int>(split[1]));
                setMarginBottom(stdext::safe_cast<int>(split[2]));
                setMarginLeft(stdext::safe_cast<int>(split[3]));
            } else if (split.size() == 3) {
                int marginTop = stdext::safe_cast<int>(split[0]);
                int marginHorizontal = stdext::safe_cast<int>(split[1]);
                int marginBottom = stdext::safe_cast<int>(split[2]);
                setMarginTop(marginTop);
                setMarginRight(marginHorizontal);
                setMarginBottom(marginBottom);
                setMarginLeft(marginHorizontal);
            } else if (split.size() == 2) {
                int marginVertical = stdext::safe_cast<int>(split[0]);
                int marginHorizontal = stdext::safe_cast<int>(split[1]);
                setMarginTop(marginVertical);
                setMarginRight(marginHorizontal);
                setMarginBottom(marginVertical);
                setMarginLeft(marginHorizontal);
            } else if (split.size() == 1) {
                int margin = stdext::safe_cast<int>(split[0]);
                setMarginTop(margin);
                setMarginRight(margin);
                setMarginBottom(margin);
                setMarginLeft(margin);
            }
        } else if (node->tag() == "padding-top")
            setPaddingTop(node->value<int>());
        else if (node->tag() == "padding-right")
            setPaddingRight(node->value<int>());
        else if (node->tag() == "padding-bottom")
            setPaddingBottom(node->value<int>());
        else if (node->tag() == "padding-left")
            setPaddingLeft(node->value<int>());
        else if (node->tag() == "padding") {
            std::string paddingDesc = node->value();
            std::vector<std::string> split = stdext::split(paddingDesc, " ");
            if (split.size() == 4) {
                setPaddingTop(stdext::safe_cast<int>(split[0]));
                setPaddingRight(stdext::safe_cast<int>(split[1]));
                setPaddingBottom(stdext::safe_cast<int>(split[2]));
                setPaddingLeft(stdext::safe_cast<int>(split[3]));
            } else if (split.size() == 3) {
                int paddingTop = stdext::safe_cast<int>(split[0]);
                int paddingHorizontal = stdext::safe_cast<int>(split[1]);
                int paddingBottom = stdext::safe_cast<int>(split[2]);
                setPaddingTop(paddingTop);
                setPaddingRight(paddingHorizontal);
                setPaddingBottom(paddingBottom);
                setPaddingLeft(paddingHorizontal);
            } else if (split.size() == 2) {
                int paddingVertical = stdext::safe_cast<int>(split[0]);
                int paddingHorizontal = stdext::safe_cast<int>(split[1]);
                setPaddingTop(paddingVertical);
                setPaddingRight(paddingHorizontal);
                setPaddingBottom(paddingVertical);
                setPaddingLeft(paddingHorizontal);
            } else if (split.size() == 1) {
                int padding = stdext::safe_cast<int>(split[0]);
                setPaddingTop(padding);
                setPaddingRight(padding);
                setPaddingBottom(padding);
                setPaddingLeft(padding);
            }
        }
        // layouts
        else if (node->tag() == "layout") {
            std::string layoutType;
            if (node->hasValue())
                layoutType = node->value();
            else
                layoutType = node->valueAt<std::string>("type", "");

            if (!layoutType.empty()) {
                UILayoutPtr layout;
                if (layoutType == "horizontalBox")
                    layout = std::make_shared<UIHorizontalLayout>(static_self_cast<UIWidget>());
                else if (layoutType == "verticalBox")
                    layout = std::make_shared<UIVerticalLayout>(static_self_cast<UIWidget>());
                else if (layoutType == "grid")
                    layout = std::make_shared<UIGridLayout>(static_self_cast<UIWidget>());
                else if (layoutType == "anchor")
                    layout = std::make_shared<UIAnchorLayout>(static_self_cast<UIWidget>());
                else
                    throw OTMLException(node, "cannot determine layout type");
                setLayout(layout);
            }

            if (node->hasChildren())
                m_layout->applyStyle(node);
        }
        // anchors
        else if (node->tag().starts_with("anchors.")) {
            const auto& parent = getParent();
            if (!parent) {
                if (hasProp(PropFirstOnStyle))
                    throw OTMLException(node, "cannot create anchor, there is no parent widget!");
                continue;
            }

            const auto& layout = parent->getLayout();
            UIAnchorLayoutPtr anchorLayout;
            if (layout->isUIAnchorLayout())
                anchorLayout = layout->static_self_cast<UIAnchorLayout>();

            if (!anchorLayout)
                throw OTMLException(node, "cannot create anchor, the parent widget doesn't use anchor layout!");

            std::string what = node->tag().substr(8);
            if (what == "fill") {
                fill(node->value());
            } else if (what == "centerIn") {
                centerIn(node->value());
            } else {
                Fw::AnchorEdge anchoredEdge = Fw::translateAnchorEdge(what);

                if (node->value() == "none") {
                    removeAnchor(anchoredEdge);
                } else {
                    std::vector<std::string> split = stdext::split(node->value(), ".");
                    if (split.size() != 2)
                        throw OTMLException(node, "invalid anchor description");

                    std::string hookedWidgetId = split[0];
                    Fw::AnchorEdge hookedEdge = Fw::translateAnchorEdge(split[1]);

                    if (anchoredEdge == Fw::AnchorNone)
                        throw OTMLException(node, "invalid anchor edge");

                    if (hookedEdge == Fw::AnchorNone)
                        throw OTMLException(node, "invalid anchor target edge");

                    addAnchor(anchoredEdge, hookedWidgetId, hookedEdge);
                }
            }
        }
    }
}

void UIWidget::drawBackground(const Rect& screenCoords) const
{
    if (m_backgroundColor.aF() > 0.0f) {
        Rect drawRect = screenCoords;
        drawRect.translate(m_backgroundRect.topLeft());
        if (m_backgroundRect.isValid())
            drawRect.resize(m_backgroundRect.size());
        g_drawPool.addFilledRect(drawRect, m_backgroundColor, m_backgroundDrawConductor);
    }
}

void UIWidget::drawBorder(const Rect& screenCoords) const
{
    // top
    if (m_borderWidth.top > 0) {
        const Rect borderRect(screenCoords.topLeft(), screenCoords.width(), m_borderWidth.top);
        g_drawPool.addFilledRect(borderRect, m_borderColor.top, m_borderDrawConductor);
    }
    // right
    if (m_borderWidth.right > 0) {
        const Rect borderRect(screenCoords.topRight() - Point(m_borderWidth.right - 1, 0), m_borderWidth.right, screenCoords.height());
        g_drawPool.addFilledRect(borderRect, m_borderColor.right, m_borderDrawConductor);
    }
    // bottom
    if (m_borderWidth.bottom > 0) {
        const Rect borderRect(screenCoords.bottomLeft() - Point(0, m_borderWidth.bottom - 1), screenCoords.width(), m_borderWidth.bottom);
        g_drawPool.addFilledRect(borderRect, m_borderColor.bottom, m_borderDrawConductor);
    }
    // left
    if (m_borderWidth.left > 0) {
        const Rect borderRect(screenCoords.topLeft(), m_borderWidth.left, screenCoords.height());
        g_drawPool.addFilledRect(borderRect, m_borderColor.left, m_borderDrawConductor);
    }
}

void UIWidget::drawIcon(const Rect& screenCoords) const
{
    if (!m_icon)
        return;

    Rect drawRect;
    if (m_iconRect.isValid()) {
        drawRect = screenCoords;
        drawRect.translate(m_iconRect.topLeft());
        drawRect.resize(m_iconRect.size());
    } else {
        drawRect.resize(m_iconClipRect.size());

        if (m_iconAlign == Fw::AlignNone)
            drawRect.moveCenter(screenCoords.center());
        else
            drawRect.alignIn(screenCoords, m_iconAlign);
    }
    drawRect.translate(m_iconOffset);
    g_drawPool.addTexturedRect(drawRect, m_icon, m_iconClipRect, m_iconColor, m_iconDrawConductor);
}

void UIWidget::setIcon(const std::string& iconFile)
{
    g_dispatcher.addEvent([&, iconFile = iconFile] {
        m_icon = iconFile.empty() ? nullptr : g_textures.getTexture(iconFile);
        if (m_icon && !m_iconClipRect.isValid()) {
            m_iconClipRect = Rect(0, 0, m_icon->getSize());
        }

        repaint();
    });
}