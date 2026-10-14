@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryScheduledFloatPoolPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ScheduledFloatPoolPolicyStore = Staffing.newMemoryScheduledFloatPoolPolicyStore()
        let item = Staffing.newScheduledFloatPoolPolicy("code-323", label: "label-773")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
