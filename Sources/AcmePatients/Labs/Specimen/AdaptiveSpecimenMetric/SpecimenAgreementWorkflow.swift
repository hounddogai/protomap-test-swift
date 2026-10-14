import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen agreements through their life cycle and keeps a journal of what it did.
    final class SpecimenAgreementWorkflow {
        var store: any SpecimenAgreementStore
        var validator: SpecimenAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SpecimenAgreementEngine

        init(store: any SpecimenAgreementStore, validator: SpecimenAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SpecimenAgreementEngine) {
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
                throw Kit.Failure("specimen agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenAgreementStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenAgreementStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen agreement \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newSpecimenAgreementWorkflow(_ store: any SpecimenAgreementStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SpecimenAgreementWorkflow {
        return SpecimenAgreementWorkflow(
            store: store,
            validator: defaultSpecimenAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultSpecimenAgreementEngine(flags)
        )
    }
}
