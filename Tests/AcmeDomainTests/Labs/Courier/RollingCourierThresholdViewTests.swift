@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingCourierThresholdViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newRollingCourierThreshold("code-71", title: "title-488")
        let view = Labs.toRollingCourierThresholdView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toRollingCourierThresholdViews([item, item]).count == 2)
    }
}
