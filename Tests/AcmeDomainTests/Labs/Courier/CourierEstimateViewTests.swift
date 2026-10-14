@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierEstimateViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierEstimate("code-533", title: "title-138")
        let view = Labs.toCourierEstimateView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierEstimateViews([item, item]).count == 2)
    }
}
