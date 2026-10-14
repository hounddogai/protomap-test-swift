@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalCourierExceptionViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = Labs.newSeasonalCourierException("code-126", title: "title-295")
        let view = Labs.toSeasonalCourierExceptionView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(Labs.toSeasonalCourierExceptionViews([item, item]).count == 2)
    }
}
