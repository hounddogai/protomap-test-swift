import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered read quotas through their life cycle and keeps a journal of what it did.
    final class TieredReadQuotaManager {
        var store: any TieredReadQuotaStore
        var validator: TieredReadQuotaValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredReadQuotaStore, validator: TieredReadQuotaValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered read quota \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredReadQuotaStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered read quota \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredReadQuotaStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newTieredReadQuotaManager(_ store: any TieredReadQuotaStore, clock: any Kit.Clocks.Clock) -> TieredReadQuotaManager {
        return TieredReadQuotaManager(
            store: store,
            validator: defaultTieredReadQuotaValidator(),
            clock: clock,
            journal: []
        )
    }
}
