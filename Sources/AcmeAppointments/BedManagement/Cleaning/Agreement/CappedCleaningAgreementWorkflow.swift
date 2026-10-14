import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves capped cleaning agreements through their life cycle and keeps a journal of what it did.
    final class CappedCleaningAgreementDesk {
        var store: any CappedCleaningAgreementStore
        var validator: CappedCleaningAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CappedCleaningAgreementEngine

        init(store: any CappedCleaningAgreementStore, validator: CappedCleaningAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CappedCleaningAgreementEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped cleaning agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CappedCleaningAgreementStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped cleaning agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CappedCleaningAgreementStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("capped cleaning agreement \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newCappedCleaningAgreementDesk(_ store: any CappedCleaningAgreementStore, clock: any Kit.Clocks.Clock) -> CappedCleaningAgreementDesk {
        return CappedCleaningAgreementDesk(
            store: store,
            validator: defaultCappedCleaningAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultCappedCleaningAgreementEngine()
        )
    }
}
