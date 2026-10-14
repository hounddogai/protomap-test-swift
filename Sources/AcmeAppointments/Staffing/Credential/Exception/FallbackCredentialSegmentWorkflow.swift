import AcmePlatform
import Foundation

extension Staffing {
    /// Moves fallback credential segments through their life cycle and keeps a journal of what it did.
    final class FallbackCredentialSegmentWorkflow {
        var store: any FallbackCredentialSegmentStore
        var validator: FallbackCredentialSegmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackCredentialSegmentStore, validator: FallbackCredentialSegmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback credential segment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackCredentialSegmentStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback credential segment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackCredentialSegmentStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newFallbackCredentialSegmentWorkflow(_ store: any FallbackCredentialSegmentStore, clock: any Kit.Clocks.Clock) -> FallbackCredentialSegmentWorkflow {
        return FallbackCredentialSegmentWorkflow(
            store: store,
            validator: defaultFallbackCredentialSegmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
