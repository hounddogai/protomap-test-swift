import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves capped census baselines through their life cycle and keeps a journal of what it did.
    final class CappedCensusBaselineService {
        var store: any CappedCensusBaselineStore
        var validator: CappedCensusBaselineValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any CappedCensusBaselineStore, validator: CappedCensusBaselineValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("capped census baseline \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedCensusBaselineStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped census baseline \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedCensusBaselineStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newCappedCensusBaselineService(_ store: any CappedCensusBaselineStore, clock: any Kit.Clocks.Clock) -> CappedCensusBaselineService {
        return CappedCensusBaselineService(
            store: store,
            validator: defaultCappedCensusBaselineValidator(),
            clock: clock,
            journal: []
        )
    }
}
