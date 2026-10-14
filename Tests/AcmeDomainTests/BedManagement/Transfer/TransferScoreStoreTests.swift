@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryTransferScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.TransferScoreStore = BedManagement.newMemoryTransferScoreStore()
        let item = BedManagement.newTransferScore("code-586", label: "label-359")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
