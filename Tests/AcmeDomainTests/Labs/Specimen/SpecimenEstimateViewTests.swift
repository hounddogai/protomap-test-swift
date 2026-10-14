@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSpecimenEstimate("code-983", name: "name-130")
        let view = Labs.toSpecimenEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSpecimenEstimateViews([item, item]).count == 2)
    }
}
