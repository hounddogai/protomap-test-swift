@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementMemoryCensusPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any BedManagement.CensusPreferenceStore = BedManagement.newMemoryCensusPreferenceStore()
        let item = BedManagement.newCensusPreference("code-556", title: "title-277")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
