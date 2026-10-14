@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenEntry("code-1", label: "label-929")
        let view = Labs.toSpecimenEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenEntryViews([item, item]).count == 2)
    }
}
