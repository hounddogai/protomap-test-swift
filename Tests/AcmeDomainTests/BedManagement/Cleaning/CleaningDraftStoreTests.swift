@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCleaningDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CleaningDraftStore = BedManagement.newMemoryCleaningDraftStore()
        let item = BedManagement.newCleaningDraft("code-414", title: "title-802")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
