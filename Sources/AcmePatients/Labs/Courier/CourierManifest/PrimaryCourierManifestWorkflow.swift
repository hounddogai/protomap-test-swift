import AcmePlatform
import Foundation

extension Labs {
    /// Moves primary courier manifests through their life cycle and keeps a journal of what it did.
    final class PrimaryCourierManifestWorkflow {
        var store: any PrimaryCourierManifestStore
        var validator: PrimaryCourierManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryCourierManifestEngine

        init(store: any PrimaryCourierManifestStore, validator: PrimaryCourierManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryCourierManifestEngine) {
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
                throw Kit.Failure("primary courier manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryCourierManifestStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary courier manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryCourierManifestStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary courier manifest \(code) not found")
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
                if item.expiresAt > cutoff {
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

    static func newPrimaryCourierManifestWorkflow(_ store: any PrimaryCourierManifestStore, clock: any Kit.Clocks.Clock) -> PrimaryCourierManifestWorkflow {
        return PrimaryCourierManifestWorkflow(
            store: store,
            validator: defaultPrimaryCourierManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryCourierManifestEngine()
        )
    }
}
