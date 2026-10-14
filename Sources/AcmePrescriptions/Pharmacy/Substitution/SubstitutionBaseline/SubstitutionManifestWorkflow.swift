import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves substitution manifests through their life cycle and keeps a journal of what it did.
    final class SubstitutionManifestDesk {
        var store: any SubstitutionManifestStore
        var validator: SubstitutionManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SubstitutionManifestEngine

        init(store: any SubstitutionManifestStore, validator: SubstitutionManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SubstitutionManifestEngine) {
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
                throw Kit.Failure("substitution manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SubstitutionManifestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SubstitutionManifestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("substitution manifest \(code) not found")
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
                if item.updatedAt > cutoff {
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

    static func newSubstitutionManifestDesk(_ store: any SubstitutionManifestStore, clock: any Kit.Clocks.Clock) -> SubstitutionManifestDesk {
        return SubstitutionManifestDesk(
            store: store,
            validator: defaultSubstitutionManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultSubstitutionManifestEngine()
        )
    }
}
