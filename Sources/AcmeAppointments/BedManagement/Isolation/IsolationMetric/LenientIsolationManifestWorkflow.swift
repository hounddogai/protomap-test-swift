import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves lenient isolation manifests through their life cycle and keeps a journal of what it did.
    final class LenientIsolationManifestCoordinator {
        var store: any LenientIsolationManifestStore
        var validator: LenientIsolationManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientIsolationManifestEngine

        init(store: any LenientIsolationManifestStore, validator: LenientIsolationManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientIsolationManifestEngine) {
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
                throw Kit.Failure("lenient isolation manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientIsolationManifestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient isolation manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientIsolationManifestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient isolation manifest \(code) not found")
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

    static func newLenientIsolationManifestCoordinator(_ store: any LenientIsolationManifestStore, clock: any Kit.Clocks.Clock) -> LenientIsolationManifestCoordinator {
        return LenientIsolationManifestCoordinator(
            store: store,
            validator: defaultLenientIsolationManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientIsolationManifestEngine()
        )
    }
}
