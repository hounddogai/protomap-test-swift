import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves formulary proposals through their life cycle and keeps a journal of what it did.
    final class FormularyProposalCoordinator {
        var store: any FormularyProposalStore
        var validator: FormularyProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: FormularyProposalEngine

        init(store: any FormularyProposalStore, validator: FormularyProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: FormularyProposalEngine) {
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
                throw Kit.Failure("formulary proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FormularyProposalStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FormularyProposalStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("formulary proposal \(code) not found")
            }
            let result = engine.run(item)
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

    static func newFormularyProposalCoordinator(_ store: any FormularyProposalStore, clock: any Kit.Clocks.Clock) -> FormularyProposalCoordinator {
        return FormularyProposalCoordinator(
            store: store,
            validator: defaultFormularyProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultFormularyProposalEngine()
        )
    }
}
