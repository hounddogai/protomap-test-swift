@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictSpecimenEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newStrictSpecimenEntry("code-190", name: "name-725")
        let view = Labs.toStrictSpecimenEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toStrictSpecimenEntryViews([item, item]).count == 2)
    }
}
