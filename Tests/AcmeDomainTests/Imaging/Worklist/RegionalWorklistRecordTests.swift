@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingRegionalWorklistRecordTests {
    @Test func startsInNew() throws {
        let item = Imaging.newRegionalWorklistRecord("code-25", label: "label-134")
        #expect(item.status == Imaging.RegionalWorklistRecordStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Imaging.newRegionalWorklistRecord("code-25", label: "label-134")
        try item.moveTo(Imaging.RegionalWorklistRecordStatus.done)
        #expect(item.status == Imaging.RegionalWorklistRecordStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newRegionalWorklistRecord("code-25", label: "label-134")
        item.status = Imaging.RegionalWorklistRecordStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.RegionalWorklistRecordStatus.new) }
    }
}
