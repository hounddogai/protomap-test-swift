@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolPlanStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolPlanStore = Staffing.newMemoryFloatPoolPlanStore()
        let item = Staffing.newFloatPoolPlan("code-888", title: "title-929")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
