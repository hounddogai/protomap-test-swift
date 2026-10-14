import AcmePlatform
import Foundation

extension Staffing {
    /// Moves shift agreements through their life cycle and keeps a journal of what it did.
    final class ShiftAgreementDesk {
        var store: any ShiftAgreementStore
        var validator: ShiftAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ShiftAgreementEngine

        init(store: any ShiftAgreementStore, validator: ShiftAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ShiftAgreementEngine) {
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
                throw Kit.Failure("shift agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ShiftAgreementStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ShiftAgreementStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("shift agreement \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newShiftAgreementDesk(_ store: any ShiftAgreementStore, clock: any Kit.Clocks.Clock) -> ShiftAgreementDesk {
        return ShiftAgreementDesk(
            store: store,
            validator: defaultShiftAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultShiftAgreementEngine()
        )
    }
}
