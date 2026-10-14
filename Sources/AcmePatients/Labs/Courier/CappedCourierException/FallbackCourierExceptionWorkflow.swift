import AcmePlatform
import Foundation

extension Labs {
    /// Moves fallback courier exceptions through their life cycle and keeps a journal of what it did.
    final class FallbackCourierExceptionCoordinator {
        var store: any FallbackCourierExceptionStore
        var validator: FallbackCourierExceptionValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackCourierExceptionStore, validator: FallbackCourierExceptionValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback courier exception \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackCourierExceptionStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback courier exception \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackCourierExceptionStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newFallbackCourierExceptionCoordinator(_ store: any FallbackCourierExceptionStore, clock: any Kit.Clocks.Clock) -> FallbackCourierExceptionCoordinator {
        return FallbackCourierExceptionCoordinator(
            store: store,
            validator: defaultFallbackCourierExceptionValidator(),
            clock: clock,
            journal: []
        )
    }
}
