@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryFloatPoolEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.FloatPoolEntryStore = Staffing.newMemoryFloatPoolEntryStore()
        let item = Staffing.newFloatPoolEntry("code-583", name: "name-975")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
