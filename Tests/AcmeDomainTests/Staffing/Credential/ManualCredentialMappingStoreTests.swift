@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingMemoryManualCredentialMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Staffing.ManualCredentialMappingStore = Staffing.newMemoryManualCredentialMappingStore()
        let item = Staffing.newManualCredentialMapping("code-887", name: "name-814")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
