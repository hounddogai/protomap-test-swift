import AcmePlatform
import Foundation

extension Labs {
    /// Moves specimen variances through their life cycle and keeps a journal of what it did.
    final class SpecimenVarianceCoordinator {
        var store: any SpecimenVarianceStore
        var validator: SpecimenVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SpecimenVarianceEngine

        init(store: any SpecimenVarianceStore, validator: SpecimenVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SpecimenVarianceEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SpecimenVarianceStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SpecimenVarianceStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("specimen variance \(code) not found")
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

    static func newSpecimenVarianceCoordinator(_ store: any SpecimenVarianceStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SpecimenVarianceCoordinator {
        return SpecimenVarianceCoordinator(
            store: store,
            validator: defaultSpecimenVarianceValidator(),
            clock: clock,
            journal: [],
            engine: defaultSpecimenVarianceEngine(flags)
        )
    }
}
