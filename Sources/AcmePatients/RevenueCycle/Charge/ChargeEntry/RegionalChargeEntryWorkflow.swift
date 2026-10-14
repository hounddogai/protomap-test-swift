import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves regional charge entries through their life cycle and keeps a journal of what it did.
    final class RegionalChargeEntryService {
        var store: any RegionalChargeEntryStore
        var validator: RegionalChargeEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RegionalChargeEntryEngine

        init(store: any RegionalChargeEntryStore, validator: RegionalChargeEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RegionalChargeEntryEngine) {
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
                throw Kit.Failure("regional charge entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RegionalChargeEntryStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional charge entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RegionalChargeEntryStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("regional charge entry \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newRegionalChargeEntryService(_ store: any RegionalChargeEntryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RegionalChargeEntryService {
        return RegionalChargeEntryService(
            store: store,
            validator: defaultRegionalChargeEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultRegionalChargeEntryEngine(flags)
        )
    }
}
