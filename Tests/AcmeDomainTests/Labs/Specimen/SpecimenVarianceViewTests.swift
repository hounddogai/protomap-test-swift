@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenVarianceViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenVariance("code-668", title: "title-473")
        let view = Labs.toSpecimenVarianceView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenVarianceViews([item, item]).count == 2)
    }
}
