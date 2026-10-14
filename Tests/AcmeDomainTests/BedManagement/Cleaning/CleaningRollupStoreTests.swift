@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningRollupStore = BedManagement.newMemoryCleaningRollupStore()
        let item = BedManagement.newCleaningRollup("code-612", label: "label-325")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
