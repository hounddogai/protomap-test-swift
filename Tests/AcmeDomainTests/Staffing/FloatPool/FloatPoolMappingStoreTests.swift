@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolMappingStore = Staffing.newMemoryFloatPoolMappingStore()
        let item = Staffing.newFloatPoolMapping("code-264", title: "title-936")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
