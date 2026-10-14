@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolVarianceStore = Staffing.newMemoryFloatPoolVarianceStore()
        let item = Staffing.newFloatPoolVariance("code-709", label: "label-792")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
