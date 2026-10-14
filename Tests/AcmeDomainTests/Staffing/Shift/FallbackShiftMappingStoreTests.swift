@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFallbackShiftMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FallbackShiftMappingStore = Staffing.newMemoryFallbackShiftMappingStore()
        let item = Staffing.newFallbackShiftMapping("code-594", name: "name-982")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
