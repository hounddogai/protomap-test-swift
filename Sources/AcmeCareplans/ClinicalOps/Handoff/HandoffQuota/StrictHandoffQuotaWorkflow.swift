import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves strict handoff quotas through their life cycle and keeps a journal of what it did.
    final class StrictHandoffQuotaService {
        var store: any StrictHandoffQuotaStore
        var validator: StrictHandoffQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any StrictHandoffQuotaStore, validator: StrictHandoffQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict handoff quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StrictHandoffQuotaStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("strict handoff quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StrictHandoffQuotaStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newStrictHandoffQuotaService(_ store: any StrictHandoffQuotaStore, clock: any Kit.Clocks.Clock) -> StrictHandoffQuotaService {
        return StrictHandoffQuotaService(
            store: store,
            validator: defaultStrictHandoffQuotaValidator(),
            clock: clock,
            journal: []
        )
    }
}
