@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCareProtocolWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CareProtocolWindowStore = ClinicalOps.newMemoryCareProtocolWindowStore()
        let item = ClinicalOps.newCareProtocolWindow("code-812", title: "title-319")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
