import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves regional claim records through their life cycle and keeps a journal of what it did.
    final class RegionalClaimRecordDesk {
        var store: any RegionalClaimRecordStore
        var validator: RegionalClaimRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalClaimRecordEngine

        init(store: any RegionalClaimRecordStore, validator: RegionalClaimRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalClaimRecordEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional claim record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalClaimRecordStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional claim record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalClaimRecordStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional claim record \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newRegionalClaimRecordDesk(_ store: any RegionalClaimRecordStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalClaimRecordDesk {
        return RegionalClaimRecordDesk(
            store: store,
            validator: defaultRegionalClaimRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalClaimRecordEngine(flags)
        )
    }
}
