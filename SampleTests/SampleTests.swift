//
//  SampleTests.swift
//  SampleTests
//
//  Created by Tanishk Deo on 6/26/21.
//

import XCTest
@testable import Sample

class SampleTests: XCTestCase {
    
    let viewModel = ViewModel(audioService: AudioRecordingService(), apiService: APIService())
    
    func testStartsAtFalse() {
        XCTAssertEqual(try viewModel.isLoading.toBlocking().first(), false)
        XCTAssertEqual(try viewModel.isPlaying.toBlocking().first(), false)
        XCTAssertEqual(try viewModel.speechText.toBlocking().first(), "")
        XCTAssertEqual(try viewModel.attributedSpeechText.toBlocking().first(), NSAttributedString(string: ""))
        XCTAssertEqual(try viewModel.recordTitle.toBlocking().first(), "Record")
    }

}
