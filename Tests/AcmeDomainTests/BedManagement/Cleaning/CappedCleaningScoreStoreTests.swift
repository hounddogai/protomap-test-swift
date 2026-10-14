@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCappedCleaningScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CappedCleaningScoreStore = BedManagement.newMemoryCappedCleaningScoreStore()
        let item = BedManagement.newCappedCleaningScore("code-303", label: "label-569")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
