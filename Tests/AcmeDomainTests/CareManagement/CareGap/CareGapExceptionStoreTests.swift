@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapExceptionStore = CareManagement.newMemoryCareGapExceptionStore()
        let item = CareManagement.newCareGapException("code-500", title: "title-694")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
