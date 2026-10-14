import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves global handoff manifests through their life cycle and keeps a journal of what it did.
    final class GlobalHandoffManifestWorkflow {
        var store: any GlobalHandoffManifestStore
        var validator: GlobalHandoffManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalHandoffManifestEngine

        init(store: any GlobalHandoffManifestStore, validator: GlobalHandoffManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalHandoffManifestEngine) {
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
                throw Kit.Failure("global handoff manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalHandoffManifestStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global handoff manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalHandoffManifestStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global handoff manifest \(code) not found")
            }
            let result = engine.run(item)
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

    static func newGlobalHandoffManifestWorkflow(_ store: any GlobalHandoffManifestStore, clock: any Kit.Clocks.Clock) -> GlobalHandoffManifestWorkflow {
        return GlobalHandoffManifestWorkflow(
            store: store,
            validator: defaultGlobalHandoffManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalHandoffManifestEngine()
        )
    }
}
