@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenRecordViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenRecord("code-38", name: "name-773")
        let view = Labs.toSpecimenRecordView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenRecordViews([item, item]).count == 2)
    }
}
