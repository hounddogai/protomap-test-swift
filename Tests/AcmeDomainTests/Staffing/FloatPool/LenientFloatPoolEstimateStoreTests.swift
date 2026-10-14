@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryLenientFloatPoolEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.LenientFloatPoolEstimateStore = Staffing.newMemoryLenientFloatPoolEstimateStore()
        let item = Staffing.newLenientFloatPoolEstimate("code-899", title: "title-403")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
