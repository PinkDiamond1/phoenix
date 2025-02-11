/*
 * Copyright 2021 ACINQ SAS
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package fr.acinq.phoenix.android.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.DialogProperties
import fr.acinq.phoenix.android.R
import fr.acinq.phoenix.android.utils.borderColor
import fr.acinq.phoenix.android.utils.mutedTextColor


/** Button for navigation purpose, with the back arrow. */
@Composable
fun BackButton(onClick: () -> Unit) {
    Button(
        onClick = onClick,
        shape = RoundedCornerShape(topStart = 0.dp, topEnd = 50.dp, bottomEnd = 50.dp, bottomStart = 0.dp),
        contentPadding = PaddingValues(start = 20.dp, top = 8.dp, bottom = 8.dp, end = 16.dp),
        colors = ButtonDefaults.buttonColors(
            backgroundColor = Color.Unspecified,
            disabledBackgroundColor = Color.Unspecified,
            contentColor = MaterialTheme.colors.onSurface,
            disabledContentColor = mutedTextColor(),
        ),
        elevation = null,
        modifier = Modifier.size(width = 62.dp, height = 52.dp)
    ) {
        PhoenixIcon(resourceId = R.drawable.ic_arrow_back, Modifier.width(24.dp))
    }
}

@Composable
fun Dialog(
    onDismiss: () -> Unit,
    title: String? = null,
    properties: DialogProperties = DialogProperties(),
    isScrollable: Boolean = true,
    buttons: (@Composable () -> Unit)? = null,
    content: @Composable () -> Unit,
) {
    androidx.compose.ui.window.Dialog(onDismissRequest = onDismiss, properties = properties) {
        Column(
            Modifier
                .padding(vertical = 50.dp, horizontal = 16.dp) // min padding for tall/wide dialogs
                .clip(MaterialTheme.shapes.large)
                .background(MaterialTheme.colors.surface)
                .widthIn(max = 600.dp)
                .then(
                    if (isScrollable) {
                        Modifier.verticalScroll(rememberScrollState())
                    } else {
                        Modifier
                    }
                )
        ) {
            // optional title
            title?.run {
                Text(text = title, modifier = Modifier.padding(24.dp), style = MaterialTheme.typography.subtitle2.copy(fontSize = 20.sp))
            }
            // content, must set the padding etc...
            content()
            // buttons
            Row(
                modifier = Modifier.align(Alignment.End)
            ) {
                if (buttons != null) {
                    buttons()
                } else {
                    Button(onClick = onDismiss, text = stringResource(id = R.string.btn_ok), padding = PaddingValues(16.dp))
                }
            }
        }
    }
}

@Composable
fun HSeparator(
    width: Dp? = null,
) {
    Box(
        (width?.run { Modifier.width(width) } ?: Modifier.fillMaxWidth())
            .height(1.dp)
            .background(color = borderColor())
    )
}

@Composable
fun VSeparator(
    padding: PaddingValues = PaddingValues(0.dp)
) {
    Box(
        Modifier
            .fillMaxHeight()
            .width(1.dp)
            .padding(padding)
            .background(color = borderColor())
    )
}

@Composable
fun PrimarySeparator(
    modifier: Modifier = Modifier, width: Dp = 50.dp, height: Dp = 8.dp
) {
    Surface(
        shape = CircleShape,
        color = MaterialTheme.colors.primary,
        modifier = modifier
            .width(width)
            .height(height)
    ) { }
}

@Composable
fun Card(
    modifier: Modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
    internalPadding: PaddingValues = PaddingValues(0.dp),
    shape: Shape = RoundedCornerShape(16.dp),
    content: @Composable () -> Unit
) {
    Column(
        modifier = modifier
            .clip(shape)
            .background(MaterialTheme.colors.surface)
            .padding(internalPadding)
    ) {
        content()
    }
}

fun Modifier.enableOrFade(enabled: Boolean): Modifier = this.then(Modifier.alpha(if (enabled) 1f else 0.3f))
