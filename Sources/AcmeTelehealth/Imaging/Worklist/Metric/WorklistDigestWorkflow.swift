import AcmePlatform
import Foundation

extension Imaging {
    /// Moves worklist digests through their life cycle and keeps a journal of what it did.
    final class WorklistDigestCoordinator {
        var store: any WorklistDigestStore
        var validator: WorklistDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: WorklistDigestEngine

        init(store: any WorklistDigestStore, validator: WorklistDigestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: WorklistDigestEngine) {
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
                throw Kit.Failure("worklist digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(WorklistDigestStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(WorklistDigestStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("worklist digest \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newWorklistDigestCoordinator(_ store: any WorklistDigestStore, clock: any Kit.Clocks.Clock) -> WorklistDigestCoordinator {
        return WorklistDigestCoordinator(
            store: store,
            validator: defaultWorklistDigestValidator(),
            clock: clock,
            journal: [],
            engine: defaultWorklistDigestEngine()
        )
    }
}
