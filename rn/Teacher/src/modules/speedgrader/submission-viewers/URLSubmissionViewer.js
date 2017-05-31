// @flow

import React, { Component } from 'react'
import {
  View,
  Text,
  Image,
  ScrollView,
  StyleSheet,
  Linking,
} from 'react-native'
import i18n from 'format-message'
import { Paragraph } from '../../../common/text'
import { LinkButton } from '../../../common/buttons'

type Props = {
  submission: Submission,
}

type State = {
  aspectRatio: number,
  size: { width: number, height: number },
}

export default class URLSubmissionViewer extends Component {
  props: Props
  state: State

  constructor (props: Props) {
    super(props)

    this.state = {
      aspectRatio: 4.0 / 3.0,
      size: { width: 375, height: 667 },
    }
    this.fetchImageSize(this.previewImageURL(props))
  }

  previewImageURL (props: Props): ?string {
    if (!(props.submission.attachments && props.submission.attachments.length > 0)) {
      return null
    }

    return props.submission.attachments[0].url
  }

  fetchImageSize = (url: ?string) => {
    if (url) {
      Image.getSize(url, this.imageSizeLoaded)
    }
  }

  imageSizeLoaded = (width: number, height: number) => {
    this.setState({ aspectRatio: width / height })
  }

  onScrollViewLayout = ({ nativeEvent }: { nativeEvent: { layout: { width: number, height: number }}}) => {
    const { width, height } = nativeEvent.layout
    this.setState({ size: { width, height } })
  }

  onFollowLink = () => {
    if (this.props.submission.url) {
      Linking.openURL(this.props.submission.url)
    }
  }

  componentWillReceiveProps (newProps: Props) {
    const newURL = this.previewImageURL(newProps)
    if (newURL && newURL !== this.previewImageURL(this.props)) {
      this.fetchImageSize(newURL)
    }
  }

  render () {
    const previewUnavailable = i18n('Preview Unavailable')
    const submissionExplaination = i18n('This submission is a URL to an external page. We\'ve included a snapshot of what the page looked like when it was submitted.')
    const preview = i18n('URL Preview Image')

    const { submission } = this.props
    const imageHeight = this.state.size.width / this.state.aspectRatio

    const image = submission.attachments && submission.attachments.length > 0
      ? <ScrollView
          onLayout={this.onScrollViewLayout}
          contentContainerStyle={styles.scrollView}
          maximumZoomScale={2.0}
          minimumZoomScale={0.5}
          showsHorizontalScrollIndicator
          showsVerticalScrollIndicator
        >
          <Image
            accessible
            accessibilityLabel={preview}
            testID='url-submission-viewer.preview'
            style={[styles.image, { height: imageHeight }]}
            source={{ uri: submission.attachments[0].url }}
          />
        </ScrollView>
      : <Paragraph style={{ alignSelf: 'center' }}>
          {previewUnavailable}
        </Paragraph>

    return (
      <View style={{ flex: 1 }}>
        <Text
          testID='url-submission-viewer.explanation'
        >
          {submissionExplaination}
        </Text>
        <LinkButton
          testID='url-submission-viewer.url'
          style={styles.linkButton}
          onPress={this.onFollowLink}
        >
          { submission.url || '' }
        </LinkButton>
        {image}
      </View>
    )
  }
}

const styles = StyleSheet.create({
  scrollView: {
    alignItems: 'center',
    justifyContent: 'flex-start',
  },
  image: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
  },
  linkButton: {
    alignSelf: 'center',
    paddingVertical: 12,
    fontSize: 18,
  },
})
