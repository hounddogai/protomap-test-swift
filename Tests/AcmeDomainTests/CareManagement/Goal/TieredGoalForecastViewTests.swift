@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredGoalForecastViewTests {
    @Test func showsTheStatusInCapitals() throws {
        let item = CareManagement.newTieredGoalForecast("code-406", name: "name-392")
        let view = CareManagement.toTieredGoalForecastView(item)
        #expect(view.statusLabel == "\(item.status.rawValue)".uppercased())
        #expect(CareManagement.toTieredGoalForecastViews([item, item]).count == 2)
    }
}
