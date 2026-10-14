@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryRegionalIsolationDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.RegionalIsolationDraftStore = BedManagement.newMemoryRegionalIsolationDraftStore()
        let item = BedManagement.newRegionalIsolationDraft("code-893", name: "name-70")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
