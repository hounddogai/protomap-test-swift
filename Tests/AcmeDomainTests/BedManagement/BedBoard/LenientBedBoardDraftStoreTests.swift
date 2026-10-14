@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryLenientBedBoardDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.LenientBedBoardDraftStore = BedManagement.newMemoryLenientBedBoardDraftStore()
        let item = BedManagement.newLenientBedBoardDraft("code-692", label: "label-263")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
