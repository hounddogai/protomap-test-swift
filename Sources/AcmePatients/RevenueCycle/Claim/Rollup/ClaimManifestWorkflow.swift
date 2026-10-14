import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim manifests through their life cycle and keeps a journal of what it did.
    final class ClaimManifestDesk {
        var store: any ClaimManifestStore
        var validator: ClaimManifestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ClaimManifestEngine

        init(store: any ClaimManifestStore, validator: ClaimManifestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ClaimManifestEngine) {
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
                throw Kit.Failure("claim manifest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimManifestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim manifest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimManifestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim manifest \(code) not found")
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

    static func newClaimManifestDesk(_ store: any ClaimManifestStore, clock: any Kit.Clocks.Clock) -> ClaimManifestDesk {
        return ClaimManifestDesk(
            store: store,
            validator: defaultClaimManifestValidator(),
            clock: clock,
            journal: [],
            engine: defaultClaimManifestEngine()
        )
    }
}
