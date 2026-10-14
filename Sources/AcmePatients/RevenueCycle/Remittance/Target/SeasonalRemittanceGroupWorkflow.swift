import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves seasonal remittance groups through their life cycle and keeps a journal of what it did.
    final class SeasonalRemittanceGroupCoordinator {
        var store: any SeasonalRemittanceGroupStore
        var validator: SeasonalRemittanceGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SeasonalRemittanceGroupEngine

        init(store: any SeasonalRemittanceGroupStore, validator: SeasonalRemittanceGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SeasonalRemittanceGroupEngine) {
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
                throw Kit.Failure("seasonal remittance group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SeasonalRemittanceGroupStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal remittance group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SeasonalRemittanceGroupStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("seasonal remittance group \(code) not found")
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

    static func newSeasonalRemittanceGroupCoordinator(_ store: any SeasonalRemittanceGroupStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SeasonalRemittanceGroupCoordinator {
        return SeasonalRemittanceGroupCoordinator(
            store: store,
            validator: defaultSeasonalRemittanceGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultSeasonalRemittanceGroupEngine(flags)
        )
    }
}
