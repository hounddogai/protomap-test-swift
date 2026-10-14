import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap agreements through their life cycle and keeps a journal of what it did.
    final class CareGapAgreementWorkflow {
        var store: any CareGapAgreementStore
        var validator: CareGapAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareGapAgreementEngine

        init(store: any CareGapAgreementStore, validator: CareGapAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareGapAgreementEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapAgreementStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapAgreementStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap agreement \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newCareGapAgreementWorkflow(_ store: any CareGapAgreementStore, clock: any Kit.Clocks.Clock) -> CareGapAgreementWorkflow {
        return CareGapAgreementWorkflow(
            store: store,
            validator: defaultCareGapAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareGapAgreementEngine()
        )
    }
}
