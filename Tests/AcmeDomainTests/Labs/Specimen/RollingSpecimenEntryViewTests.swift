@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingSpecimenEntryViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingSpecimenEntry("code-894", title: "title-658")
        let view = Labs.toRollingSpecimenEntryView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingSpecimenEntryViews([item, item]).count == 2)
    }
}
