@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryRegionalFloatPoolVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.RegionalFloatPoolVarianceStore = Staffing.newMemoryRegionalFloatPoolVarianceStore()
        let item = Staffing.newRegionalFloatPoolVariance("code-444", title: "title-9")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
