@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierPolicyViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newCourierPolicy("code-675", name: "name-96")
        let view = Labs.toCourierPolicyView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toCourierPolicyViews([item, item]).count == 2)
    }
}
