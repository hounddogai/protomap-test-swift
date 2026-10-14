@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledReferenceRangeRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newScheduledReferenceRangeRecord("code-551", label: "label-90")
        let view = Labs.toScheduledReferenceRangeRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toScheduledReferenceRangeRecordViews([item, item]).count == 2)
    }
}
